import {
  CardDef,
  field,
  contains,
  containsMany,
  linksTo,
  Component,
} from 'https://cardstack.com/base/card-api';
import StringField from 'https://cardstack.com/base/string';
import NumberField from 'https://cardstack.com/base/number';
import enumField from 'https://cardstack.com/base/enum';
import UserIcon from '@cardstack/boxel-icons/user';
import { Staff } from './staff';
import { ScheduleItem } from './schedule-item';
import { Alert } from './alert';

const LocationField = enumField(StringField, {
  options: ['In Classroom', 'At Specialists', 'Absent'],
});

export class Student extends CardDef {
  static displayName = 'Student';
  static icon = UserIcon;

  @field name = contains(StringField);
  @field shortName = contains(StringField);
  @field grade = contains(StringField);
  @field age = contains(NumberField);
  @field location = contains(LocationField);
  @field locationDetail = contains(StringField);
  @field returnTime = contains(StringField);
  @field avatar = contains(StringField);
  @field tags = containsMany(StringField);
  @field supportStaff = linksTo(Staff);
  @field schedule = containsMany(ScheduleItem);
  @field alerts = containsMany(Alert);

  @field title = contains(StringField, {
    computeVia: function (this: Student) {
      return this.name ?? 'Unnamed Student';
    },
  });

  static isolated = class Isolated extends Component<typeof Student> {
    get safeName() {
      return this.args.model?.name ?? 'Unnamed Student';
    }

    get safeGrade() {
      return this.args.model?.grade ?? '';
    }

    get safeAge() {
      return this.args.model?.age;
    }

    get safeLocation() {
      return this.args.model?.location ?? 'In Classroom';
    }

    get safeAvatar() {
      return this.args.model?.avatar ?? 'https://via.placeholder.com/200x200/5c5650/FFFFFF?text=?';
    }

    get safeTags() {
      return this.args.model?.tags ?? [];
    }

    get locationColor() {
      switch (this.safeLocation) {
        case 'In Classroom': return '#2a9d8f';
        case 'At Specialists': return '#c08b30';
        case 'Absent': return '#e05d50';
        default: return '#8a8279';
      }
    }

    get hasAlerts() {
      return (this.args.model?.alerts?.length ?? 0) > 0;
    }

    get hasSchedule() {
      return (this.args.model?.schedule?.length ?? 0) > 0;
    }

    <template>
      <article class='student-profile'>
        <header class='profile-header'>
          <div class='avatar-large'>
            <img src={{this.safeAvatar}} alt='{{this.safeName}}' />
          </div>
          <div class='header-info'>
            <h1 class='student-name'>{{this.safeName}}</h1>
            <p class='student-meta'>
              {{this.safeGrade}}
              {{#if this.safeAge}}
                &middot; Age {{this.safeAge}}
              {{/if}}
            </p>
            <div class='header-badges'>
              <span class='location-badge' style='background-color: {{this.locationColor}}'>
                {{this.safeLocation}}
              </span>
              {{#each this.safeTags as |tag|}}
                <span class='tag-badge'>{{tag}}</span>
              {{/each}}
            </div>
          </div>
        </header>

        {{#if @model.supportStaff}}
          <section class='section'>
            <h2 class='section-title'>Support Staff</h2>
            <@fields.supportStaff @format='embedded' />
          </section>
        {{/if}}

        {{#if this.hasAlerts}}
          <section class='section'>
            <h2 class='section-title'>Alerts</h2>
            <div class='alerts-list'>
              <@fields.alerts />
            </div>
          </section>
        {{/if}}

        {{#if this.hasSchedule}}
          <section class='section'>
            <h2 class='section-title'>Today's Schedule</h2>
            <div class='schedule-list'>
              <@fields.schedule />
            </div>
          </section>
        {{/if}}

        {{#if @model.locationDetail}}
          <section class='section'>
            <h2 class='section-title'>Location Detail</h2>
            <p class='location-detail'>
              {{@model.locationDetail}}
              {{#if @model.returnTime}}
                &middot; {{@model.returnTime}}
              {{/if}}
            </p>
          </section>
        {{/if}}
      </article>

      <style scoped>
        .student-profile {
          width: 100%;
          max-width: 42rem;
          margin: 0 auto;
          padding: var(--boxel-sp-xl);
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-lg);
          background-color: var(--card);
          color: var(--card-foreground);
          border-radius: var(--boxel-border-radius-lg);
        }

        .profile-header {
          display: flex;
          align-items: center;
          gap: var(--boxel-sp-lg);
          padding-bottom: var(--boxel-sp-lg);
          border-bottom: 2px solid var(--border);
        }

        .avatar-large {
          flex-shrink: 0;
          width: 7rem;
          height: 7rem;
          border-radius: 50%;
          overflow: hidden;
          border: 3px solid var(--border);
        }

        .avatar-large img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .header-info {
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-xs);
        }

        .student-name {
          font-size: var(--boxel-font-size-2xl);
          font-weight: 700;
          margin: 0;
          color: #1a1816;
        }

        .student-meta {
          font-size: var(--boxel-font-size);
          color: #5c5650;
          margin: 0;
        }

        .header-badges {
          display: flex;
          flex-wrap: wrap;
          gap: 0.375rem;
          margin-top: 0.25rem;
        }

        .location-badge {
          padding: 0.2rem 0.625rem;
          border-radius: 1rem;
          color: white;
          font-weight: 600;
          font-size: 0.6875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .tag-badge {
          padding: 0.2rem 0.5rem;
          border-radius: 4px;
          background: rgba(224, 93, 80, 0.1);
          color: #e05d50;
          font-weight: 600;
          font-size: 0.6875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .section {
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-sm);
        }

        .section-title {
          font-size: var(--boxel-font-size);
          font-weight: 700;
          margin: 0;
          color: #1a1816;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          font-size: 0.6875rem;
        }

        .alerts-list,
        .schedule-list {
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-xs);
        }

        .location-detail {
          font-size: var(--boxel-font-size-sm);
          color: #5c5650;
          margin: 0;
        }
      </style>
    </template>
  };

  static embedded = class Embedded extends Component<typeof Student> {
    get safeName() {
      return this.args.model?.shortName ?? this.args.model?.name ?? 'Unknown';
    }

    get safeAvatar() {
      return this.args.model?.avatar ?? 'https://via.placeholder.com/60x60/5c5650/FFFFFF?text=?';
    }

    get safeTags() {
      return this.args.model?.tags ?? [];
    }

    get safeLocation() {
      return this.args.model?.location ?? 'In Classroom';
    }

    get locationColor() {
      switch (this.safeLocation) {
        case 'In Classroom': return '#2a9d8f';
        case 'At Specialists': return '#c08b30';
        case 'Absent': return '#e05d50';
        default: return '#8a8279';
      }
    }

    get staffInitials() {
      return this.args.model?.supportStaff?.initials ?? null;
    }

    get staffColor() {
      switch (this.args.model?.supportStaff?.color) {
        case 'coral': return '#e05d50';
        case 'teal': return '#2a9d8f';
        case 'purple': return '#7c5fc4';
        case 'amber': return '#c08b30';
        default: return '#5c5650';
      }
    }

    <template>
      <div class='student-embedded'>
        <div class='avatar-wrapper'>
          <img src={{this.safeAvatar}} alt='{{this.safeName}}' />
          <span class='status-dot' style='background-color: {{this.locationColor}}'></span>
        </div>
        <div class='info'>
          <div class='name'>{{this.safeName}}</div>
          <div class='badges'>
            {{#each this.safeTags as |tag|}}
              <span class='tag'>{{tag}}</span>
            {{/each}}
          </div>
        </div>
        {{#if this.staffInitials}}
          <div class='staff-mini' style='background-color: {{this.staffColor}}'>
            {{this.staffInitials}}
          </div>
        {{/if}}
      </div>

      <style scoped>
        .student-embedded {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          padding: 0.5rem;
          background-color: var(--card);
          border: 1px solid var(--border);
          border-radius: var(--boxel-border-radius);
          height: 100%;
        }

        .avatar-wrapper {
          position: relative;
          flex-shrink: 0;
          width: 2.25rem;
          height: 2.25rem;
        }

        .avatar-wrapper img {
          width: 100%;
          height: 100%;
          border-radius: 50%;
          object-fit: cover;
        }

        .status-dot {
          position: absolute;
          bottom: -1px;
          right: -1px;
          width: 0.625rem;
          height: 0.625rem;
          border-radius: 50%;
          border: 2px solid var(--card);
        }

        .info {
          flex: 1;
          min-width: 0;
          display: flex;
          flex-direction: column;
          gap: 0.125rem;
        }

        .name {
          font-weight: 700;
          font-size: 0.8125rem;
          color: var(--card-foreground);
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .badges {
          display: flex;
          gap: 0.25rem;
        }

        .tag {
          font-size: 0.5625rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          padding: 0.0625rem 0.3125rem;
          border-radius: 3px;
          background: rgba(224, 93, 80, 0.1);
          color: #e05d50;
        }

        .staff-mini {
          flex-shrink: 0;
          width: 1.5rem;
          height: 1.5rem;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-size: 0.5rem;
          font-weight: 700;
          letter-spacing: 0.05em;
        }
      </style>
    </template>
  };

  static fitted = class Fitted extends Component<typeof Student> {
    get safeName() {
      return this.args.model?.shortName ?? this.args.model?.name ?? 'Unknown';
    }

    get safeAvatar() {
      return this.args.model?.avatar ?? 'https://via.placeholder.com/80x80/5c5650/FFFFFF?text=?';
    }

    get safeLocation() {
      return this.args.model?.location ?? 'In Classroom';
    }

    get locationColor() {
      switch (this.safeLocation) {
        case 'In Classroom': return '#2a9d8f';
        case 'At Specialists': return '#c08b30';
        case 'Absent': return '#e05d50';
        default: return '#8a8279';
      }
    }

    <template>
      <div class='fitted-container'>
        <div class='tile'>
          <div class='avatar-fitted'>
            <img src={{this.safeAvatar}} alt='{{this.safeName}}' />
          </div>
          <div class='fitted-name'>{{this.safeName}}</div>
          <span class='location-dot' style='background-color: {{this.locationColor}}'></span>
        </div>
      </div>

      <style scoped>
        .fitted-container {
          container-type: size;
          width: 100%;
          height: 100%;
        }

        .tile {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: var(--boxel-sp-xs);
          padding: var(--boxel-sp);
          background-color: var(--card);
          border: 1px solid var(--border);
          border-radius: var(--boxel-border-radius);
          height: 100%;
        }

        .avatar-fitted {
          width: 4rem;
          height: 4rem;
          border-radius: 50%;
          overflow: hidden;
        }

        .avatar-fitted img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .fitted-name {
          font-weight: 700;
          font-size: var(--boxel-font-size-sm);
          color: var(--card-foreground);
          text-align: center;
        }

        .location-dot {
          width: 0.5rem;
          height: 0.5rem;
          border-radius: 50%;
        }
      </style>
    </template>
  };

  static edit = class Edit extends Component<typeof Student> {
    <template>
      <div class='card-edit'>
        <div class='field-row'>
          <label>Name</label>
          <@fields.name />
        </div>
        <div class='field-row'>
          <label>Short Name</label>
          <@fields.shortName />
        </div>
        <div class='field-row'>
          <label>Grade</label>
          <@fields.grade />
        </div>
        <div class='field-row'>
          <label>Age</label>
          <@fields.age />
        </div>
        <div class='field-row'>
          <label>Location</label>
          <@fields.location />
        </div>
        <div class='field-row'>
          <label>Location Detail</label>
          <@fields.locationDetail />
        </div>
        <div class='field-row'>
          <label>Return Time</label>
          <@fields.returnTime />
        </div>
        <div class='field-row'>
          <label>Avatar URL</label>
          <@fields.avatar />
        </div>
        <div class='field-row'>
          <label>Tags</label>
          <@fields.tags />
        </div>
        <div class='field-row'>
          <label>Support Staff</label>
          <@fields.supportStaff />
        </div>
        <div class='field-row'>
          <label>Schedule</label>
          <@fields.schedule />
        </div>
        <div class='field-row'>
          <label>Alerts</label>
          <@fields.alerts />
        </div>
      </div>

      <style scoped>
        .card-edit {
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-sm);
          padding: var(--boxel-sp-sm);
          border: 1px solid var(--border);
          border-radius: var(--boxel-border-radius);
        }

        .field-row {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
        }

        .field-row label {
          font-size: var(--boxel-font-size-xs);
          font-weight: 600;
          color: var(--muted-foreground);
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }
      </style>
    </template>
  };
}
